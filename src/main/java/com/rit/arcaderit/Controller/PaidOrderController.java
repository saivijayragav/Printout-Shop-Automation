package com.rit.arcaderit.Controller;

import com.rit.arcaderit.DTO.OrderSummaryDTO;
import com.rit.arcaderit.DTO.PaidOrderDTO;
import com.rit.arcaderit.Entity.PaidOrder;
import com.rit.arcaderit.Service.PaidOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@CrossOrigin("*")
public class PaidOrderController {

    private final   PaidOrderService orderService;



    @GetMapping("/summary")
    public List<OrderSummaryDTO> getAdminOrders() {
        return orderService.getAllOrderSummaries();
    }

    @GetMapping("/processed")
    public List<OrderSummaryDTO> getProcessedOrders() {
        return orderService.getProcessedOrderSummaries();
    }

    @GetMapping("/not-processed")
    public List<OrderSummaryDTO> getNotProcessedOrders() {
        return orderService.getNotProcessedOrderSummaries();
    }

    @PostMapping("/pay")
    public ResponseEntity<PaidOrder> processOrder(@RequestBody PaidOrderDTO orderDto) {
        return ResponseEntity.ok(orderService.saveOrder(orderDto));
    }

    @GetMapping("/{orderId}")
    public ResponseEntity<?> getOrder(@PathVariable String orderId) {
        try {
            PaidOrder order = orderService.getOrderDetails(orderId);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            String message = e.getMessage();
            if (message != null && message.contains("already scanned")) {
                // QR code expired / already processed
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(Map.of("error", message, "expired", true));
            }
            // Order not found
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", message));
        }
    }

    @GetMapping("/info/{orderId}")
    public ResponseEntity<?> getOrderInfo(@PathVariable String orderId) {
        try {
            PaidOrder order = orderService.getOrderInfo(orderId);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{orderId}")
    public ResponseEntity<?> deleteOrder(@PathVariable String orderId) {
        try {
            orderService.deleteOrder(orderId);
            return ResponseEntity.ok(Map.of("message", "Order deleted successfully"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/{orderId}/restore")
    public ResponseEntity<?> restoreOrder(@PathVariable String orderId) {
        try {
            PaidOrder order = orderService.restoreOrder(orderId);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        }
    }
}