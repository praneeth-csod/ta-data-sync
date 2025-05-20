package com.cornerstone.vc.syn.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
    // Ensure the package and imports are correct
@Component
public class KafkaJobRequisitionListener {

    private final ObjectMapper objectMapper;
    private final ElasticsearchService elasticsearchService;

    @Value("${elasticsearch.index}")
    private String elasticIndex;

    public KafkaJobRequisitionListener(ObjectMapper objectMapper, ElasticsearchService elasticsearchService) {
        this.objectMapper = objectMapper;
        this.elasticsearchService = elasticsearchService;
    }

    @KafkaListener(topics = {"datasync.public.job_requisitions", "datasync.public.job_requisition_skills"}, groupId = "job-requisition-consumer-group")
    public void listen(ConsumerRecord<String, String> record) throws Exception {
        String topic = record.topic();
        String message = record.value();
    
        if (topic.equals("datasync.public.job_requisitions")) {
            JobRequisitionPayload payload = objectMapper.readValue(message, JobRequisitionPayload.class);
            elasticsearchService.indexJob(payload);
            System.out.println("Received message from topic: " + topic);
            System.out.println("Message: " + message);
        } else if (topic.equals("datasync.public.job_requisition_skills")) {
            SkillRequisitionPayload payload = objectMapper.readValue(message, SkillRequisitionPayload.class);
            elasticsearchService.mergeSkillIntoJob(payload);
            System.out.println("Received message from topic: " + topic);
            System.out.println("Message: " + message);
        }
    }
    
}