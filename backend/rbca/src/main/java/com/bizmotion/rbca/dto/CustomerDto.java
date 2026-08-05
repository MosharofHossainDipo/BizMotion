package com.bizmotion.rbca.dto;
import lombok.AllArgsConstructor;
import lombok.Getter;
import java.time.Instant;

@Getter @AllArgsConstructor
public class CustomerDto {
    private Long    id;
    private String  customerCode;
    private String  name;
    private String  customerType;
    private String  industry;
    private String  email;
    private String  phone;
    private String  company;
    private String  website;
    private String  address;
    private String  customerGroup;
    private String  preferredLanguage;
    private String  notes;
    private boolean portalAccess;
    private String  portalUsername;
    private String  status;
    private Long    createdBy;
    private Instant createdAt;
    private Instant updatedAt;
}