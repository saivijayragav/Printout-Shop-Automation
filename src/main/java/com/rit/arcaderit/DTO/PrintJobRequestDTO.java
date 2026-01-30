package com.rit.arcaderit.DTO;


import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PrintJobRequestDTO {

    // File Details
    @NotNull(message = "File name is required")
    private String fileName;

    private String binding;

    // Accepts 1 (Color) or 0 (BW)
    private Integer color;

    private Integer copies;

    private Integer sides; // 1 or 2

    // Mapped from the first 'pages' input
    private Integer pagesPerSheet;

    // Mapped from the second 'pages' input
    private Integer totalPages;

    // Customer Details
    @NotNull(message = "Customer name is required")
    private String customerName;

    @NotNull(message = "Phone number is required")
    private Long phoneNumber;

    // Raw timestamp string from the client
    private String timestamp;
}