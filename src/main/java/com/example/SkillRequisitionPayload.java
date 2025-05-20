package com.example;
import lombok.Data;

@Data
public class SkillRequisitionPayload {
    private String id;
    private String skillId;
    private String jobRequisitionId;
    private boolean isRequired;
    private int skillLevel;
    private String createdBy;
    private String updatedBy;
}