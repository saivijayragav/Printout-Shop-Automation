package com.rit.arcaderit.DTO;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FileItemDTO {
    @JsonProperty("pages")
    private Integer totalPages;
    private String name;

    private Integer copies;
    private String binding;

    // 0 = BW, 1 = Color
    private Integer color;

    // 1, 2, or 4 pages per side
    private Integer sides;

    @Data
    static
    class FileDetailDTO {
        private String name;
        private double size;
        private int pages;
        private int copies;
        private String type;
        private String binding;
        private String color;
        private String sides;
    }
}