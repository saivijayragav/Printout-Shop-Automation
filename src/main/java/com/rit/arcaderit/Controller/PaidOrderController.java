package com.rit.arcaderit.Controller;

import com.rit.arcaderit.DTO.OrderSummaryDTO;
import com.rit.arcaderit.DTO.PaidOrderDTO;
import com.rit.arcaderit.Entity.PaidOrder;
import com.rit.arcaderit.Service.PaidOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class PaidOrderController {

    private final   PaidOrderService orderService;

    

    @GetMapping("/summary")
    public List<OrderSummaryDTO> getAdminOrders() {
        return orderService.getAllOrderSummaries();
    }

    @PostMapping("/pay")
    public ResponseEntity<PaidOrder> processOrder(@RequestBody PaidOrderDTO orderDto) {
        return ResponseEntity.ok(orderService.saveOrder(orderDto));
    }

    @GetMapping("/{orderId}")
    public ResponseEntity<PaidOrder> getOrder(@PathVariable String orderId) {
        return ResponseEntity.ok(orderService.getOrderDetails(orderId));
    }
}