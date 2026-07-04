package com.bizmotion.rbca.security;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    @Autowired private JwtUtil        jwtUtil;
    @Autowired private RoleScopeCache roleScopeCache;
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response); return;
        }
        String token = authHeader.substring(7);
        if (!jwtUtil.isValid(token)) {
            filterChain.doFilter(request, response); return;
        }
        String username = jwtUtil.extractUsername(token);
        String role     = jwtUtil.extractRole(token);
        Set<String> scopes = roleScopeCache.getScopesForRole(role);
        List<SimpleGrantedAuthority> authorities = new ArrayList<>();
        for (String scope : scopes) {
            authorities.add(new SimpleGrantedAuthority(scope));
        }
        authorities.add(new SimpleGrantedAuthority("ROLE_" + role));
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(username, null, authorities);
        SecurityContextHolder.getContext().setAuthentication(auth);
        filterChain.doFilter(request, response);
    }
}
