package io.containerapps.javaruntime.workshop.quarkus;

import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.lang.System.Logger;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;



import static java.lang.System.Logger.Level.INFO;
import static java.lang.invoke.MethodHandles.lookup;


@Path("/quarkus")
@Produces(MediaType.TEXT_PLAIN)
public class QuarkusResource {

    private static final Logger LOGGER = System.getLogger(lookup().lookupClass().getName());

    private final StatisticsRepository repository;

    public QuarkusResource(StatisticsRepository statisticsRepository) {
        this.repository = statisticsRepository;
    }


    @GET
    @Path("/hello")
    @Produces(MediaType.APPLICATION_JSON)
    public HashMap<String, String> hello(@QueryParam("name") @DefaultValue("World") String name) {
        LOGGER.log(INFO, "Saying hello to %s".formatted(name));
        HashMap<String, String> response = new HashMap<>();
        response.put("message", "Hello, %s!".formatted(name));
        return response;
    }

    @GET
    @Path("/stats")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Statistics> getStatistics(@QueryParam("from") String from,
                                         @QueryParam("to") String to) {
        Instant fromInstant = from != null ? Instant.parse(from) : Instant.EPOCH;
        Instant toInstant = to != null ? Instant.parse(to) : Instant.now();
        LOGGER.log(INFO, "Fetching statistics from %s to %s".formatted(fromInstant, toInstant));
        return repository.getStatisticsBetween(fromInstant, toInstant);
    }

    @GET
    @Path("/stats2")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Statistics> stats2() {
        LOGGER.log(INFO, "Quarkus: retrieving statistics");
        return Statistics.findAll().list();
    }

    @GET
    @Path("/cpu")
    public String cpu(@QueryParam("iterations") @DefaultValue("10") Long iterations,
                    @QueryParam("db") @DefaultValue("false") Boolean db,
                    @QueryParam("desc") String desc) {
        LOGGER.log(INFO, "Quarkus: cpu: {0} {1} with desc {2}", iterations, db, desc);
        Long iterationsDone = iterations;

        Instant start = Instant.now();
        if (iterations == null) {
            iterations = 20000L;
        } else {
            iterations *= 20000;
        }
        while (iterations > 0) {
            if (iterations % 20000 == 0) {
                try {
                    Thread.sleep(20);
                } catch (InterruptedException ie) {
                }
            }
            iterations--;
        }

        if (db) {
            Statistics statistics = new Statistics();
            statistics.type = Type.CPU;
            statistics.parameter = iterations.toString();
            statistics.duration = Duration.between(start, Instant.now());
            statistics.description = desc;
            repository.persist(statistics);
        }

        String msg = "Quarkus: CPU consumption is done with " + iterationsDone + " iterations in " + Duration.between(start, Instant.now()).getNano() + " nano-seconds.";
        if (db) {
            msg += " The result is persisted in the database.";
        }
        return msg;
    }

    @GET
    @Path("/memory")
    public String memory(@QueryParam("bites") @DefaultValue("10") Integer bites,
                        @QueryParam("db") @DefaultValue("false") Boolean db,
                        @QueryParam("desc") String desc) {
        LOGGER.log(INFO, "Quarkus: memory: {0} {1} with desc {2}", bites, db, desc);

        Instant start = Instant.now();
        if (bites == null) {
            bites = 1;
        }
        HashMap<Integer, byte[]> hunger = new HashMap<>();
        for (int i = 0; i < bites * 1024 * 1024; i += 8192) {
            byte[] bytes = new byte[8192];
            hunger.put(i, bytes);
            for (int j = 0; j < 8192; j++) {
                bytes[j] = '0';
            }
        }

        if (db) {
            Statistics statistics = new Statistics();
            statistics.type = Type.MEMORY;
            statistics.parameter = bites.toString();
            statistics.duration = Duration.between(start, Instant.now());
            statistics.description = desc;
            repository.persist(statistics);
        }

        String msg = "Quarkus: Memory consumption is done with " + bites + " bites in " + Duration.between(start, Instant.now()).getNano() + " nano-seconds.";
        if (db) {
            msg += " The result is persisted in the database.";
        }
        return msg;
    }
    // Let's also create a method to retrieve the statistics from the database. This is very easy to do with Panache.

    // Listing 5. Method Returning all the Statistics
    @GET
    @Path("/stats")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Statistics> stats() {
        LOGGER.log(INFO, "Quarkus: retrieving statistics");
        return Statistics.findAll().list();
    }
}