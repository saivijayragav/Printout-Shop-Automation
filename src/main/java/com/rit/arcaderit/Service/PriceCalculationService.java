package com.rit.arcaderit.Service;

import com.rit.arcaderit.DTO.FileItemDTO;
import com.rit.arcaderit.DTO.PriceEstimateDTO;
import com.rit.arcaderit.Entity.PriceSetting;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
public class PriceCalculationService {

    private final PriceSettingService settingService;

    public Map<String, Object> calculateReceipt(PriceEstimateDTO request) {
        // 1. Fetch the latest rates from the database
        PriceSetting rates = settingService.getPricing();
        double grandTotal = 0.0;
        List<Map<String, Object>> items = new ArrayList<>();

        if (request.getFiles() != null) {
            for (FileItemDTO file : request.getFiles()) {
                // Input handling
                int pg = (file.getTotalPages() != null) ? file.getTotalPages() : 0;
                int cp = (file.getCopies() != null) ? file.getCopies() : 1;

                // sideMode: 1 = Single Side, 2 = Double Sided
                int sideMode = (file.getSides() != null) ? file.getSides() : 1;
                boolean isColor = (file.getColor() != null && file.getColor() == 1);

                double printCost = 0;
                double appliedBwRate = 0;
                double appliedColRate = 0;

                // 2. Logic for Double Sided (2-Side)
                if (sideMode == 2) {
                    int fullDoubleSidedSheets = pg / 2; // e.g., 8 / 2 = 4
                    int remainingSinglePages = pg % 2;  // e.g., 9 % 2 = 1

                    // Correct rate mapping
                    double doubleRate = isColor ? rates.getRateColor2() : rates.getRateBw2();
                    double singleRate = isColor ? rates.getRateColor1() : rates.getRateBw1();

                    // Calculation
                    printCost = (fullDoubleSidedSheets * doubleRate * cp) +
                            (remainingSinglePages * singleRate * cp);

                    if (isColor) appliedColRate = doubleRate; else appliedBwRate = doubleRate;
                }
                // 3. Logic for Single Sided (1-Side)
                else {
                    double singleRate = isColor ? rates.getRateColor1() : rates.getRateBw1();
                    printCost = pg * singleRate * cp;

                    if (isColor) appliedColRate = singleRate; else appliedBwRate = singleRate;
                }

                // 4. Binding Logic
                double bCost = 0;
                if ("0".equalsIgnoreCase(file.getBinding())) {
                    bCost = rates.getCostSpiral() * cp;
                } else if ("1".equalsIgnoreCase(file.getBinding())) {
                    bCost = rates.getCostSoft() * cp;
                }

                double total = printCost + bCost;

                // 5. Build Response Map for Flutter Receipt model
                Map<String, Object> item = new HashMap<>();
                item.put("description", (file.getName() != null && !file.getName().isEmpty()) ? file.getName() : "Untitled");
                item.put("pages", pg);
                item.put("sides", sideMode);
                item.put("bwRate", isColor ? 0.0 : appliedBwRate);
                item.put("colorRate", isColor ? appliedColRate : 0.0);
                item.put("cost", total);

                String bindingName = "No Binding";
                if ("0".equals(file.getBinding())) bindingName = "Spiral Binding";
                else if ("1".equals(file.getBinding())) bindingName = "Soft Binding";
                item.put("bindingNote", (sideMode == 2 ? "Double-Sided" : "Single-Sided") + " | " + bindingName);

                items.add(item);
                grandTotal += total;
            }
        }

        // 6. Final Receipt Envelope
        Map<String, Object> res = new HashMap<>();
        res.put("totalPrice", grandTotal);
        res.put("currency", "INR");
        res.put("items", items);
        return res;
    }
}