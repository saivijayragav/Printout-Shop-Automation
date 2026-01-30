package com.rit.arcaderit.Service;

import com.rit.arcaderit.DTO.PriceSettingDTO;
import com.rit.arcaderit.Entity.PriceSetting;
import com.rit.arcaderit.Repository.PriceSettingRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PriceSettingService {

    private final PriceSettingRepository repository;
    private static final String SETTING_ID = "GLOBAL_PRICING";

    // 1. Get the Full Configuration
    public PriceSetting getPricing() {
        return repository.findById(SETTING_ID).orElseThrow(() ->
                new RuntimeException("Pricing settings not initialized"));
    }

    // 2. Save the Full Input
    public void savePricing(PriceSettingDTO dto) {
        PriceSetting setting = PriceSetting.builder()
                .id(SETTING_ID)
                .rateBw1(dto.getRateBw1())
                .rateBw2(dto.getRateBw2())
                .rateBw4(dto.getRateBw4())
                .rateColor1(dto.getRateColor1())
                .rateColor2(dto.getRateColor2())
                .rateColor4(dto.getRateColor4())
                .costSpiral(dto.getCostSpiral())
                .costSoft(dto.getCostSoft())
                .build();
        repository.save(setting);
    }

    // Initialize with default values if table is empty
    @PostConstruct
    public void init() {
        if (!repository.existsById(SETTING_ID)) {
            PriceSettingDTO defaults = new PriceSettingDTO();
            defaults.setRateBw1(2.0); defaults.setRateBw2(1.5); defaults.setRateBw4(1.0);
            defaults.setRateColor1(10.0); defaults.setRateColor2(8.0); defaults.setRateColor4(5.0);
            defaults.setCostSpiral(50.0); defaults.setCostSoft(100.0);
            savePricing(defaults);
        }
    }
}