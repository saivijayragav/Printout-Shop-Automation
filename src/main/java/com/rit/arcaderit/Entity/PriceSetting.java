package com.rit.arcaderit.Entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.*;

@Entity
@Table(name = "price_settings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PriceSetting {
    @Id
    private String id; // We will use "GLOBAL_PRICING"

    private double rateBw1;
    private double rateBw2;
    private double rateBw4;

    private double rateColor1;
    private double rateColor2;
    private double rateColor4;

    private double costSpiral;
    private double costSoft;
}