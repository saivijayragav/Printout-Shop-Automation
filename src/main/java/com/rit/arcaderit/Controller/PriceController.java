package com.rit.arcaderit.Controller;

// ✅ CORRECT IMPORT: Use the wrapper class that holds the list
import com.rit.arcaderit.DTO.PriceEstimateDTO;
import com.rit.arcaderit.DTO.PrintJobRequestDTO;
import com.rit.arcaderit.Service.PriceCalculationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.Map;

@RestController
@RequestMapping("/api/price")
@RequiredArgsConstructor
public class PriceController {

    private final PriceCalculationService priceService;

    @PostMapping("/estimate")
    public ResponseEntity<Map<String, Object>> getPriceEstimate(@RequestBody PriceEstimateDTO request) {
        Map<String, Object> response = priceService.calculateReceipt(request);
        return ResponseEntity.ok(response);
    }
}