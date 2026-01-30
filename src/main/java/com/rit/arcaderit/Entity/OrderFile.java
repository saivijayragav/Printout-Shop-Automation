package com.rit.arcaderit.Entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "order_files", indexes = {@Index(name = "idx_file_order_id", columnList = "order_id_fk")})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderFile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private double size;
    private int pages;
    private int copies;
    private String type;
    private String binding;
    private String color;
    private String sides;
}