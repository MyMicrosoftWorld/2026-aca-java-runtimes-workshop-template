package io.containerapps.javaruntime.workshop.micronaut;

import io.micronaut.runtime.EmbeddedApplication;
import io.micronaut.test.extensions.junit5.annotation.MicronautTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Assertions;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Testcontainers;

import jakarta.inject.Inject;
import org.testcontainers.junit.jupiter.Container;

@Testcontainers
@MicronautTest
class MicronautAppTest {

    @Container
    private static PostgreSQLContainer<?> postgreSQLContainer = new PostgreSQLContainer("postgres:14")
        .withDatabaseName("postgres")
        .withUsername("postgres")
        .withPassword("password");

    @Inject
    EmbeddedApplication<?> application;

    @Test
    void testItWorks() {
        Assertions.assertTrue(application.isRunning());
    }

}
