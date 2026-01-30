package com.rit.arcaderit.Entity;


import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "print_orders") // Renamed table to reflect a customer order
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PrintJob {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // --- File Details ---

    @Column(name = "file_name", nullable = false)
    private String fileName; // Mapped from the first 'name' (DUMFreceipt...)

    private String binding;  // "No Binding"

    // Mapped from 0/1 input: True = Color, False = BW
    @Column(name = "is_color")
    private Boolean isColor;

    private Integer copies;

    @Column(name = "pages_per_sheet")
    private Integer pagesPerSheet; // Mapped from first 'pages' (1)

    @Column(name = "total_pages")
    private Integer totalPages;    // Mapped from second 'pages' (151)

    private Integer sides;         // 1 (Single) or 2 (Double)

    // --- Customer Details ---

    @Column(name = "customer_name")
    private String customerName;   // Mapped from the second 'name' input

    // changed to Long because 'int' is too small for 10-digit numbers
    @Column(name = "phone_number")
    private Long phoneNumber;

    // --- Metadata ---

    private LocalDateTime timestamp;
}