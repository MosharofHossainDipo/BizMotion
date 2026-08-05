package com.bizmotion.rbca.entity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.Instant;

@Entity
@Table(name = "customers")
@Getter @Setter @NoArgsConstructor
public class Customer {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name="customer_code", unique=true, nullable=false, length=50)
    private String customerCode;

    @Column(nullable=false, length=200)
    private String name;

    @Column(name="customer_type", nullable=false, length=50)
    private String customerType;

    @Column(length=100) private String industry;

    @Column(unique=true, nullable=false, length=150)
    private String email;

    @Column(length=30)  private String phone;
    @Column(length=200) private String company;
    @Column(length=200) private String website;
    @Column(length=1000) private String address;

    @Column(name="customer_group",  length=50)  private String customerGroup;
    @Column(name="preferred_language", length=50) private String preferredLanguage;
    @Column(length=2000) private String notes;

    @Column(name="portal_access", nullable=false)
    private boolean portalAccess = false;

    @Column(name="portal_username", length=100)
    private String portalUsername;

    @Column(nullable=false, length=20)
    private String status = "Active";

    @Column(name="created_by")  private Long createdBy;
    @Column(name="created_at", nullable=false, updatable=false) private Instant createdAt;
    @Column(name="updated_at", nullable=false) private Instant updatedAt;

    @PrePersist  void onCreate() { createdAt = Instant.now(); updatedAt = Instant.now(); }
    @PreUpdate   void onUpdate() { updatedAt = Instant.now(); }
}