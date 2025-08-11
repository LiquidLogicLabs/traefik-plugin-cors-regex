// CORS regex plugin package.
package traefik_plugin_cors_regex

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"regexp"
	"strings"
)

// Config the plugin configuration.
type Config struct {
	AllowOriginList  []string `json:"allowOriginList,omitempty"`
	AllowMethods     []string `json:"allowMethods,omitempty"`
	AllowHeaders     []string `json:"allowHeaders,omitempty"`
	ExposeHeaders    []string `json:"exposeHeaders,omitempty"`
	AllowCredentials bool     `json:"allowCredentials,omitempty"`
	MaxAge           int      `json:"maxAge,omitempty"`
	Debug            bool     `json:"debug,omitempty"`
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
		Debug:            false,
	}
}

// CORSRegex a plugin.
type CORSRegex struct {
	next             http.Handler
	name             string
	config           *Config
	originPatterns   []*regexp.Regexp
	originalPatterns []string
}

// Logging helper functions
func (c *CORSRegex) logDebug(format string, args ...interface{}) {
	if c.config.Debug {
		msg := fmt.Sprintf("[CORS-REGEX-DEBUG] %s", fmt.Sprintf(format, args...))
		os.Stdout.WriteString(msg + "\n")
	}
}

func (c *CORSRegex) logInfo(format string, args ...interface{}) {
	msg := fmt.Sprintf("[CORS-REGEX-INFO] %s", fmt.Sprintf(format, args...))
	os.Stdout.WriteString(msg + "\n")
}

func (c *CORSRegex) logError(format string, args ...interface{}) {
	msg := fmt.Sprintf("[CORS-REGEX-ERROR] %s", fmt.Sprintf(format, args...))
	os.Stderr.WriteString(msg + "\n")
}

// New created a new plugin.
func New(ctx context.Context, next http.Handler, config *Config, name string) (http.Handler, error) {
	plugin := &CORSRegex{
		next:   next,
		name:   name,
		config: config,
	}

	plugin.logDebug("Initializing plugin name=%s allowOrigins=%d", name, len(config.AllowOriginList))

	// Compile regex patterns and store original patterns
	for _, origin := range config.AllowOriginList {
		var regexPattern string

		if strings.Contains(origin, "*") {
			// Convert wildcard pattern to regex
			regexPattern = strings.ReplaceAll(origin, ".", "\\.")
			regexPattern = strings.ReplaceAll(regexPattern, "*", ".*")
			regexPattern = "^" + regexPattern + "$"
			plugin.logDebug("Origin pattern converted wildcard origin=%q regex=%q", origin, regexPattern)
		} else {
			// Check if the pattern contains regex special characters
			if strings.ContainsAny(origin, "[]{}()*+?|\\^$") {
				regexPattern = "^" + origin + "$"
				plugin.logDebug("Origin pattern treated as regex origin=%q regex=%q", origin, regexPattern)
			} else {
				regexPattern = "^" + regexp.QuoteMeta(origin) + "$"
				plugin.logDebug("Origin pattern exact match origin=%q regex=%q", origin, regexPattern)
			}
		}

		compiled, err := regexp.Compile(regexPattern)
		if err != nil {
			plugin.logError("Failed to compile pattern origin=%q err=%v", origin, err)
			return nil, fmt.Errorf("invalid pattern %s: %w", origin, err)
		}

		plugin.originPatterns = append(plugin.originPatterns, compiled)
		plugin.originalPatterns = append(plugin.originalPatterns, origin)
	}

	plugin.logInfo("Plugin initialized successfully name=%s compiled=%d", name, len(plugin.originPatterns))
	return plugin, nil
}

func (c *CORSRegex) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
	origin := req.Header.Get("Origin")

	c.logDebug("Processing request method=%s path=%s origin=%q", req.Method, req.URL.Path, origin)

	// Check if origin is allowed
	allowedOrigin := c.isOriginAllowed(origin)

	if allowedOrigin != "" {
		rw.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
		c.logDebug("Origin allowed matchedPattern=%q", allowedOrigin)
	} else if origin != "" {
		c.logDebug("Origin blocked origin=%q", origin)
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
		c.logDebug("Handling preflight request origin=%q", origin)
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

	for i, pattern := range c.originPatterns {
		if pattern.MatchString(origin) {
			originalPattern := c.originalPatterns[i]

			// For wildcard patterns (containing *) and regex patterns, return the actual origin
			// For exact matches, return the pattern (which should be the same as origin)
			if strings.Contains(originalPattern, "*") || strings.ContainsAny(originalPattern, "[]{}()+?|\\^$") {
				c.logDebug("Wildcard/regex pattern matched, returning actual origin pattern=%q origin=%q", originalPattern, origin)
				return origin
			}

			// For exact matches, return the original pattern
			c.logDebug("Exact pattern matched pattern=%q", originalPattern)
			return originalPattern
		}
	}

	return ""
}

// Export map used by Traefik/Yaegi in some setups.
var traefik_plugin_cors_regex = map[string]interface{}{
	"New":          New,
	"CreateConfig": CreateConfig,
}
