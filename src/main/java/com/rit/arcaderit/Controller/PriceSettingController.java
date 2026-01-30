package com.rit.arcaderit.Controller;

import com.rit.arcaderit.DTO.PriceSettingDTO;
import com.rit.arcaderit.Entity.PriceSetting;
import com.rit.arcaderit.Service.PriceSettingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class PriceSettingController {

    private final PriceSettingService service;

    @GetMapping("/pricing")
    public ResponseEntity<PriceSetting> getPricing() {
        return ResponseEntity.ok(service.getPricing());
    }

    @PutMapping("/savepricing")
    public ResponseEntity<String> savePricing(@RequestBody PriceSettingDTO dto) {
        service.savePricing(dto);
        return ResponseEntity.ok("All prices updated successfully!");
    }
}