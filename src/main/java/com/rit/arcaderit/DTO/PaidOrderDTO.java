package com.rit.arcaderit.DTO;

import lombok.Data;
import java.time.LocalDateTime; // Import this!
import java.util.List;

@Data
public class PaidOrderDTO {
    private String orderId;
    private int pages;
    private double price;
    private String userName;
    private String phoneNumber;
    private String transactionId;

    // ✅ ADD THIS FIELD to capture the input from Flutter
    private LocalDateTime timestamp;

    private List<FileDetailDTO> files;
}