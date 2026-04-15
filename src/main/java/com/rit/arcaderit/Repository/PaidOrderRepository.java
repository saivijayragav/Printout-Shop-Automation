package com.rit.arcaderit.Repository;

import com.rit.arcaderit.Entity.PaidOrder;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface PaidOrderRepository extends JpaRepository<PaidOrder, Long> {
    Optional<PaidOrder> findByOrderId(String orderId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT p FROM PaidOrder p WHERE p.orderId = :orderId")
    Optional<PaidOrder> findByOrderIdWithLock(@Param("orderId") String orderId);
}