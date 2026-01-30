package com.rit.arcaderit.DTO;

import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderSummaryDTO {
    private String orderId;       // 1. Match Query index 1
    private int totalPages;       // 2. Match Query index 2
    private double totalPrice;    // 3. Match Query index 3
    private String userName;      // 4. Match Query index 4
    private String phoneNumber;   // 5. Match Query index 5
    private String transactionId; // 6. Match Query index 6
    private LocalDateTime timestamp;     // 7. Match Query index 7
}