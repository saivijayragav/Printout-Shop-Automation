package com.rit.arcaderit.Service;
import com.rit.arcaderit.Entity.PrintJob;

import com.rit.arcaderit.DTO.PrintJobRequestDTO;
import com.rit.arcaderit.Repository.PrintJobRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

@Service
@RequiredArgsConstructor // Automatically injects the Repository (Lombok)
@Slf4j // Enables Logging
public class PrintJobService {

    private final PrintJobRepository repository;

    public PrintJob createPrintJob(PrintJobRequestDTO request) {
        log.info("Processing print job for customer: {}", request.getCustomerName());

        // 1. Convert Integer Color (1/0) to Boolean
        boolean isColor = (request.getColor() != null && request.getColor() == 1);

        // 2. Parse the custom Timestamp format
        // Input format: "25 September 2025 at 23:25:12 UTC+5:30"
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern(
                "dd MMMM yyyy 'at' HH:mm:ss 'UTC'XXX", Locale.ENGLISH);

        LocalDateTime parsedTime;
        try {
            parsedTime = LocalDateTime.parse(request.getTimestamp(), formatter);
        } catch (Exception e) {
            log.error("Date parsing failed, defaulting to NOW. Error: {}", e.getMessage());
            parsedTime = LocalDateTime.now();
        }

        // 3. Map DTO to Entity using Builder pattern
        PrintJob printJob = PrintJob.builder()
                .fileName(request.getFileName())
                .binding(request.getBinding())
                .isColor(isColor)
                .copies(request.getCopies())
                .sides(request.getSides())
                .pagesPerSheet(request.getPagesPerSheet())
                .totalPages(request.getTotalPages())
                .customerName(request.getCustomerName())
                .phoneNumber(request.getPhoneNumber())
                .timestamp(parsedTime)
                .build();

        // 4. Save to DB
        PrintJob savedJob = repository.save(printJob);
        log.info("Print job saved successfully with ID: {}", savedJob.getId());

        return savedJob;
    }
}