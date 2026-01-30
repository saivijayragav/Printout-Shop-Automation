package com.rit.arcaderit.Repository;


import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.rit.arcaderit.Entity.PrintJob;

import java.util.List;

@Repository
public interface PrintJobRepository extends JpaRepository<PrintJob, Long> {

    // ✅ Standard CRUD methods (save, findAll, findById, delete) are already included.

    // ✅ Custom Query: Find all jobs by a specific customer's phone number
    // Spring automatically parses this method name and writes the SQL for you.
    List<PrintJob> findByPhoneNumber(Long phoneNumber);

    // Optional: Find by Customer Name (Case insensitive)
    List<PrintJob> findByCustomerNameContainingIgnoreCase(String name);
}