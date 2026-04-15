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

    public List<OrderSummaryDTO> getAllOrderSummaries(){
        return repo.findAllOrderSummaries();
    }

    public List<OrderSummaryDTO> getProcessedOrderSummaries(){
        return repo.findProcessedOrderSummaries();
    }

    public List<OrderSummaryDTO> getNotProcessedOrderSummaries(){
        return repo.findNotProcessedOrderSummaries();
    }

    private final PaidOrderRepository repository;

    // Save Order (With Timestamp Fix)
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

        // Build Order Entity — processed defaults to false via @Builder.Default
        PaidOrder order = PaidOrder.builder()
                .orderId(dto.getOrderId())
                .totalPages(dto.getPages())
                .totalPrice(dto.getPrice())
                .userName(dto.getUserName())
                .phoneNumber(dto.getPhoneNumber())
                .transactionId(dto.getTransactionId())
                .timestamp(dto.getTimestamp() != null ? dto.getTimestamp() : LocalDateTime.now())
                .files(fileEntities)
                .build();

        return repository.save(order);
    }

    /**
     * Fetches order by orderId with a PESSIMISTIC_WRITE lock.
     * - If the order is not yet processed, marks it as processed and returns it.
     * - If the order is already processed, throws a RuntimeException (QR expired).
     * - The pessimistic lock ensures concurrent scans on the same orderId are serialized.
     */
    @Transactional
    public PaidOrder getOrderDetails(String orderId) {
        PaidOrder order = repository.findByOrderIdWithLock(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

        if (order.isProcessed()) {
            throw new RuntimeException("QR code already scanned / expired for order: " + orderId);
        }

        // Mark as processed and save
        order.setProcessed(true);
        return repository.save(order);
    }

    @Transactional(readOnly = true)
    public PaidOrder getOrderInfo(String orderId) {
        return repository.findByOrderId(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
    }

    @Transactional
    public void deleteOrder(String orderId) {
        PaidOrder order = repository.findByOrderId(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
        repository.delete(order);
    }

    @Transactional
    public PaidOrder restoreOrder(String orderId) {
        PaidOrder order = repository.findByOrderId(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
        order.setProcessed(false);
        return repository.save(order);
    }
}