package com.rit.arcaderit.Entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "paid_orders", indexes = {@Index(name = "idx_order_id", columnList = "orderId")})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaidOrder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String orderId;

    private int totalPages;
    private double totalPrice;
    private String userName;
    private String phoneNumber;
    private String transactionId;

    // ✅ Ensure this is LocalDateTime
    private LocalDateTime timestamp;

    @OneToMany(cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id_fk", referencedColumnName = "orderId")
    private List<OrderFile> files;
}