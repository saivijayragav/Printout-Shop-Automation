package com.rit.arcaderit.Repository;

import com.rit.arcaderit.Entity.PaidOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface PaidOrderRepository extends JpaRepository<PaidOrder, Long> {
    Optional<PaidOrder> findByOrderId(String orderId);
}