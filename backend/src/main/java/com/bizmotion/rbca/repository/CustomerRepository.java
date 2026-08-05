package com.bizmotion.rbca.repository;
import com.bizmotion.rbca.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    boolean existsByEmail(String email);
    boolean existsByCustomerCode(String customerCode);

    @Query("SELECT c.customerCode FROM Customer c WHERE c.customerCode LIKE CONCAT(:prefix, '%')")
    List<String> findCodesWithPrefix(@Param("prefix") String prefix);

    Optional<Customer> findByCustomerCode(String customerCode);
    Optional<Customer> findByEmailIgnoreCase(String email);
    Optional<Customer> findByNameIgnoreCase(String name);
}