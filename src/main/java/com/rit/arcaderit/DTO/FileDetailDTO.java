package com.rit.arcaderit.DTO;

import lombok.Data;

@Data
public class FileDetailDTO { // Added 'public' keyword
    private String name;
    private double size;
    private int pages;
    private int copies;
    private String type;
    private String binding;
    private String color;
    private String sides;
}