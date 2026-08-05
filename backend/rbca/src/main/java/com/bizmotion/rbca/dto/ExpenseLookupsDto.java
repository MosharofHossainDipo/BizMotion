package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.List;

@Getter @AllArgsConstructor
public class ExpenseLookupsDto {
    private List<String> categories;
    private List<String> staff;
    private List<String> paymentMethods;
}
