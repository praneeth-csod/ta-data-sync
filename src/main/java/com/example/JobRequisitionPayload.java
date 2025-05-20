
package com.example;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class JobRequisitionPayload {
    private String id;
    private String title;
    private String description;
    private String referenceCode;
    private String type;
    private String skillLevel;
    private String visibility;
    private List<Skill> skills;
    private LocationTime locationTime;
    private Compensation compensation;
    private Map<String, Object> metadata;
    private Status status;
    private String sponsorship;
    private String company;

    @Data
    public static class Skill {
        private String id;
    }

    @Data
    public static class LocationTime {
        private Location location;

        @Data
        public static class Location {
            private String country;
            private String formattedAddress;
        }
    }

    @Data
    public static class Compensation {
        private double payRate;
        private double maxPayRate;
        private String type;
        private String quantity;
        private String relocate;
        private String benefits;
    }

    @Data
    public static class Status {
        private String state;
    }
}