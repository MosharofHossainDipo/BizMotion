package com.bizmotion.rbca.security;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import javax.crypto.SecretKey;
import java.util.Date;
@Component
public class JwtUtil {
    @Value("${jwt.secret}")           private String secret;
    @Value("${jwt.access-expiry-ms}") private long   accessExpiryMs;
    @Value("${jwt.refresh-expiry-ms}") private long  refreshExpiryMs;
    public String generateAccessToken(String username, String role) {
        return Jwts.builder()
                .subject(username)
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + accessExpiryMs))
                .signWith(getSigningKey())
                .compact();
    }
    public String generateRefreshToken(String username) {
        return Jwts.builder()
                .subject(username)
                .claim("type", "refresh")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + refreshExpiryMs))
                .signWith(getSigningKey())
                .compact();
    }
    public String extractUsername(String token) { return parseClaims(token).getSubject(); }
    public String extractRole(String token)     { return (String) parseClaims(token).get("role"); }
    public boolean isValid(String token) {
        try { parseClaims(token); return true; } catch (Exception e) { return false; }
    }
    private Claims parseClaims(String token) {
        return Jwts.parser().verifyWith(getSigningKey()).build()
                   .parseSignedClaims(token).getPayload();
    }
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret));
    }
}
