package com.example.edgebox;

import java.util.concurrent.Executors;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

@Configuration
public class VirtualThreadsConfig {

    @Bean
    public ThreadPoolTaskExecutor applicationTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setVirtualThreadsTaskExecutor(Executors.newVirtualThreadPerTaskExecutor());
        executor.setThreadNamePrefix("edgebox-virtual-");
        executor.initialize();
        return executor;
    }
}
