INSERT INTO public.job_requisitions (
    id,
    tenant_id,
    parent_job_id,
    job_title,
    supervisory_orgs_id,
    reference_id,
    management_level,
    skill_level,
    visibility,
    external_url,
    status,
    revoked_date,
    job_start_type,
    job_start_date,
    job_type,
    compensation_type,
    pay_range_enabled,
    fixed_compensation,
    min_compensation,
    max_compensation,
    weekly_hours,
    duration_unit,
    duration,
    hiring_type,
    number_of_hires,
    location_type,
    location_id,
    is_relocation_required,
    employee_benefits_required,
    visa_included,
    created_by,
    updated_by,
    created_timestamp,
    updated_timestamp
)
VALUES (
    'job-requisition-001',               -- id
    'tenant-123',                        -- tenant_id
    NULL,                                -- parent_job_id (can be NULL)
    'Software Engineer',                 -- job_title
    'org-001',               -- supervisory_orgs_id
    'ref-123',                           -- reference_id
    'ENTRY',                         -- management_level
    'INTERMEDIATE',                      -- skill_level
    'PUBLIC',                            -- visibility
    'http://example.com/job/123',        -- external_url
    'OPEN',                              -- status
    NULL,                                -- revoked_date (can be NULL)
    'SPECIFIC_DATE',                     -- job_start_type
    '2025-06-01',                        -- job_start_date
    'FULL_TIME',                         -- job_type
    'MONTHLY',                             -- compensation_type
    TRUE,                                -- pay_range_enabled
    NULL,                                -- fixed_compensation (NULL because pay_range_enabled is true)
    50000.00,                            -- min_compensation
    100000.00,                           -- max_compensation
    40,                                  -- weekly_hours
    'MONTH',                             -- duration_unit
    12,                                  -- duration
    'LIMITED',                           -- hiring_type
    10,                                  -- number_of_hires
    'REMOTE',                            -- location_type
    'location-001',                      -- location_id
    TRUE,                                -- is_relocation_required
    TRUE,                                -- employee_benefits_required
    TRUE,                                -- visa_included
    'admin',                             -- created_by
    'admin',                             -- updated_by
    CURRENT_TIMESTAMP,                   -- created_timestamp
    CURRENT_TIMESTAMP                    -- updated_timestamp
);
INSERT INTO public.job_requisition_skills (
    id,
    tenant_id,
    job_requisition_id,
    skill_id,
    skill_level,
    is_required,
    created_by,
    updated_by,
    created_timestamp,
    updated_timestamp
)
VALUES (
    'skill-requisition-001',                -- id
    'tenant-123',                           -- tenant_id
    'job-requisition-001',                  -- job_requisition_id (must reference a valid job_requisition)
    '5c9d06964119475ec187b876',                            -- skill_id (must reference a valid skill)
    3,                                      -- skill_level (e.g., 1 = Beginner, 3 = Intermediate, 5 = Expert)
    TRUE,                                   -- is_required (true if the skill is required for the job)
    'admin',                                -- created_by
    'admin',                                -- updated_by (can be NULL if not updated)
    CURRENT_TIMESTAMP,                      -- created_timestamp (current timestamp)
    CURRENT_TIMESTAMP                       -- updated_timestamp (current timestamp)
);
