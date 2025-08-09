package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"regexp"
	"strings"
)

// Config holds the plugin configuration.
type Config struct {
	AllowOriginList  []string `json:"allowOriginList,omitempty"`
	AllowMethods     []string `json:"allowMethods,omitempty"`
	AllowHeaders     []string `json:"allowHeaders,omitempty"`
	ExposeHeaders    []string `json:"exposeHeaders,omitempty"`
	AllowCredentials bool     `json:"allowCredentials,omitempty"`
	MaxAge           int      `json:"maxAge,omitempty"`
}

// CreateConfig creates the default plugin configuration.
func CreateConfig() *Config {
	return &Config{
		AllowOriginList:  []string{},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{},
		AllowCredentials: false,
		MaxAge:           86400,
	}
}

// CORSRegex holds the necessary information to instantiate the CORS regex plugin.
type CORSRegex struct {
	next             http.Handler
	name             string
	config           *Config
	originPatterns   []*regexp.Regexp
	originalPatterns []string
}

// New creates and returns a new CORS regex plugin instance.
func New(ctx context.Context, next http.Handler, config *Config, name string) (http.Handler, error) {
	log.Printf("[CORS-REGEX] Initializing plugin '%s' with %d origin patterns", name, len(config.AllowOriginList))

	plugin := &CORSRegex{
		next:   next,
		name:   name,
		config: config,
	}

	// Compile regex patterns and store original patterns
	for _, origin := range config.AllowOriginList {
		var regexPattern string

		if strings.Contains(origin, "*") {
			// Convert wildcard pattern to regex
			regexPattern = strings.ReplaceAll(origin, ".", "\\.")
			regexPattern = strings.ReplaceAll(regexPattern, "*", ".*")
			regexPattern = "^" + regexPattern + "$"
			log.Printf("[CORS-REGEX] Converting wildcard pattern '%s' to regex: '%s'", origin, regexPattern)
		} else {
			// Check if the pattern contains regex special characters
			// If it does, treat it as a regex pattern; otherwise, treat as exact match
			if strings.ContainsAny(origin, "[]{}()*+?|\\^$") {
				// Treat as regex pattern
				regexPattern = "^" + origin + "$"
				log.Printf("[CORS-REGEX] Treating pattern '%s' as regex: '%s'", origin, regexPattern)
			} else {
				// Treat as exact match
				regexPattern = "^" + regexp.QuoteMeta(origin) + "$"
				log.Printf("[CORS-REGEX] Treating pattern '%s' as exact match: '%s'", origin, regexPattern)
			}
		}

		compiled, err := regexp.Compile(regexPattern)
		if err != nil {
			log.Printf("[CORS-REGEX] ERROR: Failed to compile pattern '%s': %v", origin, err)
			return nil, fmt.Errorf("invalid pattern %s: %w", origin, err)
		}

		plugin.originPatterns = append(plugin.originPatterns, compiled)
		plugin.originalPatterns = append(plugin.originalPatterns, origin)
		log.Printf("[CORS-REGEX] Successfully compiled pattern '%s'", origin)
	}

	log.Printf("[CORS-REGEX] Plugin '%s' initialized successfully with %d patterns", name, len(plugin.originPatterns))
	return plugin, nil
}

// ServeHTTP handles the HTTP request and adds CORS headers.
func (c *CORSRegex) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
	origin := req.Header.Get("Origin")

	log.Printf("[CORS-REGEX] Processing request from origin: '%s' for path: '%s'", origin, req.URL.Path)

	// Check if origin is allowed
	allowedOrigin := c.isOriginAllowed(origin)

	if allowedOrigin != "" {
		log.Printf("[CORS-REGEX] Origin '%s' is allowed (matched pattern: '%s')", origin, allowedOrigin)
		rw.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
	} else if origin != "" {
		log.Printf("[CORS-REGEX] Origin '%s' is NOT allowed", origin)
	}

	if len(c.config.AllowMethods) > 0 {
		rw.Header().Set("Access-Control-Allow-Methods", strings.Join(c.config.AllowMethods, ", "))
	}

	if len(c.config.AllowHeaders) > 0 {
		rw.Header().Set("Access-Control-Allow-Headers", strings.Join(c.config.AllowHeaders, ", "))
	}

	if len(c.config.ExposeHeaders) > 0 {
		rw.Header().Set("Access-Control-Expose-Headers", strings.Join(c.config.ExposeHeaders, ", "))
	}

	if c.config.AllowCredentials {
		rw.Header().Set("Access-Control-Allow-Credentials", "true")
	}

	if c.config.MaxAge > 0 {
		rw.Header().Set("Access-Control-Max-Age", fmt.Sprintf("%d", c.config.MaxAge))
	}

	// Handle preflight requests
	if req.Method == "OPTIONS" {
		log.Printf("[CORS-REGEX] Handling preflight request for origin: '%s'", origin)
		rw.WriteHeader(http.StatusOK)
		return
	}

	c.next.ServeHTTP(rw, req)
}

// isOriginAllowed checks if the given origin is allowed based on the configured patterns.
func (c *CORSRegex) isOriginAllowed(origin string) string {
	if origin == "" {
		return ""
	}

	// Check against regex patterns
	for i, pattern := range c.originPatterns {
		if pattern.MatchString(origin) {
			// Return the original pattern that was configured
			return c.originalPatterns[i]
		}
	}

	return ""
}

// main function required for Traefik plugin
func main() {
	// This function is required for the plugin to be recognized by Traefik
	// The actual plugin registration is handled by Traefik's plugin system
	log.Printf("[CORS-REGEX] Plugin loaded successfully")
}
