package com.rit.arcaderit.DTO;

import lombok.Data;
import java.util.List;

@Data
public class PriceEstimateDTO {
    private List<FileItemDTO> files;
}