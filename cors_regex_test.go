package traefik_plugin_cors_regex

import (
	"context"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
)

func TestNew(t *testing.T) {
	tests := []struct {
		name        string
		config      *Config
		expectError bool
	}{
		{
			name:        "valid config with no origins",
			config:      &Config{},
			expectError: false,
		},
		{
			name: "valid config with wildcard origins",
			config: &Config{
				AllowOriginList: []string{"https://*.example.com", "https://api.example.org"},
			},
			expectError: false,
		},
		{
			name: "valid config with regex origins",
			config: &Config{
				AllowOriginList: []string{"https://.*\\.test\\.com", "https://(dev|staging|prod)\\.app\\.com"},
			},
			expectError: false,
		},
		{
			name: "invalid regex pattern",
			config: &Config{
				AllowOriginList: []string{"https://[invalid-regex.example.com"},
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusOK)
			})

			plugin, err := New(context.Background(), next, tt.config, "test")

			if tt.expectError {
				if err == nil {
					t.Errorf("Expected error but got none")
				}
				return
			}

			if err != nil {
				t.Errorf("Unexpected error: %v", err)
				return
			}

			if plugin == nil {
				t.Errorf("Expected plugin instance but got nil")
			}
		})
	}
}

func TestCreateConfig(t *testing.T) {
	config := CreateConfig()

	if config == nil {
		t.Fatal("Expected config but got nil")
	}

	if len(config.AllowMethods) == 0 {
		t.Error("Expected default methods but got empty slice")
	}

	if len(config.AllowHeaders) == 0 {
		t.Error("Expected default headers but got empty slice")
	}

	if config.MaxAge != 86400 {
		t.Errorf("Expected MaxAge 86400 but got %d", config.MaxAge)
	}

	if config.AllowCredentials {
		t.Error("Expected AllowCredentials false but got true")
	}
}

func TestServeHTTP_AllowedOrigin(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://*.example.com", "https://api.example.org"},
		AllowMethods:    []string{"GET", "POST"},
		AllowHeaders:    []string{"Origin", "Content-Type"},
	}

	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	plugin, err := New(context.Background(), next, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}

	req := httptest.NewRequest("GET", "/test", nil)
	req.Header.Set("Origin", "https://api.example.com")
	w := httptest.NewRecorder()

	plugin.ServeHTTP(w, req)

	// After CORS fix, wildcard patterns should return the actual origin, not the pattern
	if w.Header().Get("Access-Control-Allow-Origin") != "https://api.example.com" {
		t.Errorf("Expected Access-Control-Allow-Origin header to be 'https://api.example.com', got '%s'", w.Header().Get("Access-Control-Allow-Origin"))
	}

	if w.Header().Get("Access-Control-Allow-Methods") != "GET, POST" {
		t.Errorf("Expected Access-Control-Allow-Methods header to be 'GET, POST', got '%s'", w.Header().Get("Access-Control-Allow-Methods"))
	}

	if w.Header().Get("Access-Control-Allow-Headers") != "Origin, Content-Type" {
		t.Errorf("Expected Access-Control-Allow-Headers header to be 'Origin, Content-Type', got '%s'", w.Header().Get("Access-Control-Allow-Headers"))
	}
}

func TestServeHTTP_BlockedOrigin(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://*.example.com"},
	}

	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	plugin, err := New(context.Background(), next, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}

	req := httptest.NewRequest("GET", "/test", nil)
	req.Header.Set("Origin", "https://malicious.com")
	w := httptest.NewRecorder()

	plugin.ServeHTTP(w, req)

	if w.Header().Get("Access-Control-Allow-Origin") != "" {
		t.Errorf("Expected no Access-Control-Allow-Origin header for blocked origin, got '%s'", w.Header().Get("Access-Control-Allow-Origin"))
	}
}

func TestServeHTTP_OptionsRequest(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://*.example.com"},
		AllowMethods:    []string{"GET", "POST", "OPTIONS"},
		AllowHeaders:    []string{"Origin", "Content-Type"},
	}

	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("Next handler should not be called for OPTIONS request")
	})

	plugin, err := New(context.Background(), next, config, "test")
	if err != nil {
		t.Fatalf("Failed to create plugin: %v", err)
	}

	req := httptest.NewRequest("OPTIONS", "/test", nil)
	// Use an origin that matches the wildcard pattern
	req.Header.Set("Origin", "https://api.example.com")
	w := httptest.NewRecorder()

	plugin.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200 for OPTIONS request, got %d", w.Code)
	}

	// After CORS fix, OPTIONS requests should also return the actual origin for wildcard patterns
	if w.Header().Get("Access-Control-Allow-Origin") != "https://api.example.com" {
		t.Errorf("Expected Access-Control-Allow-Origin header to be 'https://api.example.com' for OPTIONS request, got '%s'", w.Header().Get("Access-Control-Allow-Origin"))
	}
}

func TestIsOriginAllowed(t *testing.T) {
	config := &Config{
		AllowOriginList: []string{"https://*.example.com", "https://api.example.org", "https://.*\\.test\\.com"},
	}

	plugin := &CORSRegex{
		config: config,
	}

	// Compile patterns for testing
	for _, origin := range config.AllowOriginList {
		var regexPattern string
		if origin == "https://*.example.com" {
			regexPattern = "^https://.*\\.example\\.com$"
		} else if origin == "https://.*\\.test\\.com" {
			regexPattern = "^https://.*\\.test\\.com$"
		} else {
			regexPattern = "^" + origin + "$"
		}

		compiled, _ := regexp.Compile(regexPattern)
		plugin.originPatterns = append(plugin.originPatterns, compiled)
		plugin.originalPatterns = append(plugin.originalPatterns, origin)
	}

	tests := []struct {
		origin         string
		expectedResult string
	}{
		// After CORS fix: wildcard and regex patterns return the actual origin, not the pattern
		{"https://api.example.com", "https://api.example.com"}, // wildcard match returns actual origin
		{"https://www.example.com", "https://www.example.com"}, // wildcard match returns actual origin
		{"https://api.example.org", "https://api.example.org"}, // exact match returns exact origin
		{"https://sub.test.com", "https://sub.test.com"},       // regex match returns actual origin
		{"https://malicious.com", ""},                          // no match returns empty
		{"", ""},                                               // empty origin returns empty
	}

	for _, tt := range tests {
		t.Run(tt.origin, func(t *testing.T) {
			result := plugin.isOriginAllowed(tt.origin)
			if result != tt.expectedResult {
				t.Errorf("Expected '%s' for origin '%s', got '%s'", tt.expectedResult, tt.origin, result)
			}
		})
	}
}
