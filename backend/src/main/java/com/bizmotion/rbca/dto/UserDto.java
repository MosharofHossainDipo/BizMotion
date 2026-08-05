package com.bizmotion.rbca.dto;
import lombok.AllArgsConstructor;
import lombok.Getter;
@Getter
@AllArgsConstructor
public class UserDto {
    private Long    id;
    private String  username;
    private String  email;
    private String  roleName;
    private Long    roleId;
    private boolean active;
}