package main

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestCreateConfig(t *testing.T) {
	config := CreateConfig()
	
	if config == nil {
		t.Fatal("CreateConfig returned nil")
	}
	
	// Check default values
	if len(config.AllowOriginList) != 0 {
		t.Errorf("Expected empty AllowOriginList, got %v", config.AllowOriginList)
	}
	
	expectedMethods := []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	if !sliceEqual(config.AllowMethods, expectedMethods) {
		t.Errorf("Expected AllowMethods %v, got %v", expectedMethods, config.AllowMethods)
	}
	
	expectedHeaders := []string{"Origin", "Content-Type", "Accept", "Authorization"}
	if !sliceEqual(config.AllowHeaders, expectedHeaders) {
		t.Errorf("Expected AllowHeaders %v, got %v", expectedHeaders, config.AllowHeaders)
	}
	
	if config.AllowCredentials {
		t.Error("Expected AllowCredentials to be false by default")
	}
	
	if config.MaxAge != 86400 {
		t.Errorf("Expected MaxAge 86400, got %d", config.MaxAge)
	}
}

func TestNew_ValidConfig(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://example.com", "https://*.example.com"},
		AllowMethods:    []string{"GET", "POST"},
		AllowHeaders:    []string{"Content-Type"},
		AllowCredentials: true,
		MaxAge:          3600,
	}
	
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	
	plugin, err := New(context.Background(), handler, config, "test")
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	
	if plugin == nil {
		t.Fatal("Expected plugin to be created")
	}
}

func TestNew_InvalidWildcardPattern(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://[invalid.example.com"},
	}
	
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	
	_, err := New(context.Background(), handler, config, "test")
	if err == nil {
		t.Fatal("Expected error for invalid wildcard pattern")
	}
}

func TestCORSRegex_ServeHTTP_ExactMatch(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://example.com"},
		AllowMethods:    []string{"GET", "POST"},
		AllowHeaders:    []string{"Content-Type"},
		AllowCredentials: true,
		MaxAge:          3600,
	}
	
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	
	plugin, err := New(context.Background(), handler, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}
	
	req := httptest.NewRequest("GET", "/", nil)
	req.Header.Set("Origin", "https://example.com")
	w := httptest.NewRecorder()
	
	plugin.ServeHTTP(w, req)
	
	if w.Header().Get("Access-Control-Allow-Origin") != "https://example.com" {
		t.Errorf("Expected Access-Control-Allow-Origin to be 'https://example.com', got '%s'", 
			w.Header().Get("Access-Control-Allow-Origin"))
	}
	
	if w.Header().Get("Access-Control-Allow-Methods") != "GET, POST" {
		t.Errorf("Expected Access-Control-Allow-Methods to be 'GET, POST', got '%s'", 
			w.Header().Get("Access-Control-Allow-Methods"))
	}
	
	if w.Header().Get("Access-Control-Allow-Headers") != "Content-Type" {
		t.Errorf("Expected Access-Control-Allow-Headers to be 'Content-Type', got '%s'", 
			w.Header().Get("Access-Control-Allow-Headers"))
	}
	
	if w.Header().Get("Access-Control-Allow-Credentials") != "true" {
		t.Errorf("Expected Access-Control-Allow-Credentials to be 'true', got '%s'", 
			w.Header().Get("Access-Control-Allow-Credentials"))
	}
	
	if w.Header().Get("Access-Control-Max-Age") != "3600" {
		t.Errorf("Expected Access-Control-Max-Age to be '3600', got '%s'", 
			w.Header().Get("Access-Control-Max-Age"))
	}
}

func TestCORSRegex_ServeHTTP_WildcardMatch(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://*.example.com"},
		AllowMethods:    []string{"GET", "POST"},
	}
	
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	
	plugin, err := New(context.Background(), handler, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}
	
	testCases := []struct {
		origin     string
		shouldMatch bool
	}{
		{"https://sub.example.com", true},
		{"https://api.example.com", true},
		{"https://example.com", false},
		{"https://sub.example.org", false},
		{"http://sub.example.com", false},
	}
	
	for _, tc := range testCases {
		t.Run(tc.origin, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/", nil)
			req.Header.Set("Origin", tc.origin)
			w := httptest.NewRecorder()
			
			plugin.ServeHTTP(w, req)
			
			allowOrigin := w.Header().Get("Access-Control-Allow-Origin")
			if tc.shouldMatch {
				if allowOrigin != "https://*.example.com" {
					t.Errorf("Expected Access-Control-Allow-Origin to be 'https://*.example.com', got '%s'", allowOrigin)
				}
			} else {
				if allowOrigin != "" {
					t.Errorf("Expected no Access-Control-Allow-Origin header, got '%s'", allowOrigin)
				}
			}
		})
	}
}

func TestCORSRegex_ServeHTTP_NoOrigin(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://example.com"},
	}
	
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	
	plugin, err := New(context.Background(), handler, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}
	
	req := httptest.NewRequest("GET", "/", nil)
	w := httptest.NewRecorder()
	
	plugin.ServeHTTP(w, req)
	
	if w.Header().Get("Access-Control-Allow-Origin") != "" {
		t.Errorf("Expected no Access-Control-Allow-Origin header, got '%s'", 
			w.Header().Get("Access-Control-Allow-Origin"))
	}
}

func TestCORSRegex_ServeHTTP_OptionsRequest(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://example.com"},
		AllowMethods:    []string{"GET", "POST"},
		AllowHeaders:    []string{"Content-Type"},
	}
	
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	
	plugin, err := New(context.Background(), handler, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}
	
	req := httptest.NewRequest("OPTIONS", "/", nil)
	req.Header.Set("Origin", "https://example.com")
	w := httptest.NewRecorder()
	
	plugin.ServeHTTP(w, req)
	
	if w.Code != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, w.Code)
	}
	
	if w.Header().Get("Access-Control-Allow-Origin") != "https://example.com" {
		t.Errorf("Expected Access-Control-Allow-Origin to be 'https://example.com', got '%s'", 
			w.Header().Get("Access-Control-Allow-Origin"))
	}
}

func TestCORSRegex_ServeHTTP_MultiplePatterns(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{
			"https://example.com",
			"https://*.example.com",
			"https://api.example.org",
		},
	}
	
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	
	plugin, err := New(context.Background(), handler, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}
	
	testCases := []struct {
		origin     string
		expected   string
	}{
		{"https://example.com", "https://example.com"},
		{"https://sub.example.com", "https://*.example.com"},
		{"https://api.example.org", "https://api.example.org"},
		{"https://other.com", ""},
	}
	
	for _, tc := range testCases {
		t.Run(tc.origin, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/", nil)
			req.Header.Set("Origin", tc.origin)
			w := httptest.NewRecorder()
			
			plugin.ServeHTTP(w, req)
			
			allowOrigin := w.Header().Get("Access-Control-Allow-Origin")
			if allowOrigin != tc.expected {
				t.Errorf("Expected Access-Control-Allow-Origin to be '%s', got '%s'", tc.expected, allowOrigin)
			}
		})
	}
}

func TestCORSRegex_ServeHTTP_ComplexWildcardPatterns(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{
			"https://*.sub.example.com",
			"https://api.*.example.com",
			"https://*.example.*.com",
		},
	}
	
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	
	plugin, err := New(context.Background(), handler, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}
	
	testCases := []struct {
		origin     string
		expected   string
	}{
		{"https://test.sub.example.com", "https://*.sub.example.com"},
		{"https://api.prod.example.com", "https://api.*.example.com"},
		{"https://test.example.prod.com", "https://*.example.*.com"},
		{"https://invalid.example.com", ""},
	}
	
	for _, tc := range testCases {
		t.Run(tc.origin, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/", nil)
			req.Header.Set("Origin", tc.origin)
			w := httptest.NewRecorder()
			
			plugin.ServeHTTP(w, req)
			
			allowOrigin := w.Header().Get("Access-Control-Allow-Origin")
			if allowOrigin != tc.expected {
				t.Errorf("Expected Access-Control-Allow-Origin to be '%s', got '%s'", tc.expected, allowOrigin)
			}
		})
	}
}

// Helper function to compare slices
func sliceEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
