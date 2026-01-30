package com.rit.arcaderit.Service;

import com.rit.arcaderit.DTO.OrderSummaryDTO;
import com.rit.arcaderit.DTO.PaidOrderDTO;
import com.rit.arcaderit.Entity.OrderFile;
import com.rit.arcaderit.Entity.PaidOrder;
import com.rit.arcaderit.Repository.PaidOrderRepository;
import com.rit.arcaderit.Repository.ReturnPaidOrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PaidOrderService {


    private final ReturnPaidOrderRepository repo;

    public List<OrderSummaryDTO> getAllOrderSummaries() {
        return repo.findAllOrderSummaries();
    }

    private final PaidOrderRepository repository;




    // 2. Save Order (With Timestamp Fix)
    @Transactional
    public PaidOrder saveOrder(PaidOrderDTO dto) {
        // Convert File DTOs to Entities
        var fileEntities = dto.getFiles().stream().map(f -> OrderFile.builder()
                .name(f.getName())
                .size(f.getSize())
                .pages(f.getPages())
                .copies(f.getCopies())
                .type(f.getType())
                .binding(f.getBinding())
                .color(f.getColor())
                .sides(f.getSides())
                .build()).collect(Collectors.toList());

        // Build Order Entity
        PaidOrder order = PaidOrder.builder()
                .orderId(dto.getOrderId())
                .totalPages(dto.getPages())
                .totalPrice(dto.getPrice())
                .userName(dto.getUserName())
                .phoneNumber(dto.getPhoneNumber())
                .transactionId(dto.getTransactionId())

                // ✅ CRITICAL FIX: Map the timestamp here!
                // If dto.getTimestamp() is null (e.g., from old app version), default to NOW()
                .timestamp(dto.getTimestamp() != null ? dto.getTimestamp() : LocalDateTime.now())

                .files(fileEntities)
                .build();

        return repository.save(order);
    }

    public PaidOrder getOrderDetails(String orderId) {
        return repository.findByOrderId(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
    }
}