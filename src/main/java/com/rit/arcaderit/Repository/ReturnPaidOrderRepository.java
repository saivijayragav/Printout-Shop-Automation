package com.rit.arcaderit.Repository;

import com.rit.arcaderit.DTO.OrderSummaryDTO;
import com.rit.arcaderit.Entity.PaidOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ReturnPaidOrderRepository extends JpaRepository<PaidOrder, Long> {

    @Query("SELECT new com.rit.arcaderit.DTO.OrderSummaryDTO(" +
            "p.orderId, p.totalPages, p.totalPrice, p.userName, p.phoneNumber, p.transactionId, p.timestamp) " +
            "FROM PaidOrder p")
    List<OrderSummaryDTO> findAllOrderSummaries();
}