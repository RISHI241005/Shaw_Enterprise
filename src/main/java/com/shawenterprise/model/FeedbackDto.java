package com.shawenterprise.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class FeedbackDto {
    public long id;
    public String authorEmail;
    public String displayLabel;
    public String message;
    public String status;
    public LocalDateTime createdAt;
    public Map<String, Integer> reactions = new LinkedHashMap<>(Map.of("like", 0, "heart", 0));
    public String myReaction;
    public List<FeedbackDto> replies = new ArrayList<>();
}
