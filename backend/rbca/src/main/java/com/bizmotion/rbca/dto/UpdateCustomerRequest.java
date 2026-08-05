package com.bizmotion.rbca.dto;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class UpdateCustomerRequest {
    @NotBlank(message="Name is required") private String name;
    @NotBlank(message="Customer type is required") private String customerType;
    @NotBlank(message="Email is required") @Email(message="Invalid email") private String email;
    private String industry;
    private String phone;
    private String company;
    private String website;
    private String address;
    private String customerGroup;
    private String preferredLanguage;
    private String notes;
    private boolean portalAccess;
    private String portalUsername;
}