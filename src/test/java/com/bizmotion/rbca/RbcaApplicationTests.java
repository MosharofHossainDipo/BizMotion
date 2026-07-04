package com.bizmotion.rbca;

import org.junit.jupiter.api.Test;

/**
 * Basic smoke test.
 * We do NOT load the full Spring context here because
 * Oracle DB is not available in the build/CI environment yet.
 * Full integration tests will be added after DB setup is complete.
 */
class RbcaApplicationTests {

    @Test
    void contextLoads() {
        // Placeholder â€” passes immediately without starting Spring context.
        // Remove this comment and add @SpringBootTest above the class
        // once Oracle DB is configured and running.
    }

}