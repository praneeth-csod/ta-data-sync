package com.example;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import com.example.JobRequisitionPayload.Skill;

import java.util.*;

@Service
public class ElasticsearchService {

    @Value("${elasticsearch.url}")
    private String elasticUrl;

    @Value("${elasticsearch.index}")
    private String index;

    private final RestTemplate restTemplate = new RestTemplate();

    public void indexJob(JobRequisitionPayload payload) {
        String url = String.format("%s/%s/_doc/%s", elasticUrl, index, payload.getId());
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<JobRequisitionPayload> request = new HttpEntity<>(payload, headers);
        restTemplate.exchange(url, HttpMethod.PUT, request, String.class);
    }

    public void mergeSkillIntoJob(SkillRequisitionPayload skillPayload) {
        String jobId = skillPayload.getJobRequisitionId();
        String url = String.format("%s/%s/_doc/%s", elasticUrl, index, jobId);

        ResponseEntity<JobRequisitionPayload> response = restTemplate.getForEntity(url, JobRequisitionPayload.class);
        if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
            return;
        }

        JobRequisitionPayload job = response.getBody();
        List<JobRequisitionPayload.Skill> skills = job.getSkills() != null ? new ArrayList<>(job.getSkills()) : new ArrayList<>();

        Skill newSkill = new Skill();
        newSkill.setId(skillPayload.getSkillId());

        boolean exists = skills.stream().anyMatch(s -> s.getId().equals(skillPayload.getSkillId()));
        if (!exists) {
            skills.add(newSkill);
        }

        job.setSkills(skills);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<JobRequisitionPayload> request = new HttpEntity<>(job, headers);
        restTemplate.exchange(url, HttpMethod.PUT, request, String.class);
    }
}