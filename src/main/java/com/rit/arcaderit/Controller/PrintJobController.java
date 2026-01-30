package com.rit.arcaderit.Controller;

import com.rit.arcaderit.Entity.PrintJob;

import com.rit.arcaderit.DTO.PrintJobRequestDTO;
import com.rit.arcaderit.Entity.PrintJob;
import com.rit.arcaderit.Service.PrintJobService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/print-jobs")
@RequiredArgsConstructor
public class PrintJobController {

    private final PrintJobService printJobService;

    @PostMapping
    public ResponseEntity<String> createPrintJob(@Valid @RequestBody PrintJobRequestDTO request) {
        try {
            PrintJob createdJob = printJobService.createPrintJob(request);
            return new ResponseEntity<>("Job Created Successfully. ID: " + createdJob.getId(), HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>("Error processing request: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}