package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.List;

@Getter @AllArgsConstructor
public class DepositLookupsDto {
    private List<String> categories;
    private List<String> companies;
    private List<String> payers;
    private List<String> staff;
    private List<String> paymentMethods;
}
