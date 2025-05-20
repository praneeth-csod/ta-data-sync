package com.cornerstone.vc.syn.service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.data.elasticsearch.repository.config.EnableElasticsearchRepositories;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;

@SpringBootApplication
@EnableFeignClients
@EnableElasticsearchRepositories
@EnableMongoRepositories
public class DataSyncApplication {

    public static void main(String[] args) {
        SpringApplication.run(DataSyncApplication.class, args);
        System.out.println("Sync service started.");
    }
}
