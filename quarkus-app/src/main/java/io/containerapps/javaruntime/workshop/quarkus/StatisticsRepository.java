package io.containerapps.javaruntime.workshop.quarkus;

import java.time.Instant;
import java.util.List;

import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

@ApplicationScoped
@Transactional
public class StatisticsRepository implements PanacheRepository<Statistics> {

    public  List<Statistics> getStatisticsBetween(Instant from, Instant to) {
        return list("doneAt >= ?1 and doneAt <= ?2", from, to);
    }   
}
