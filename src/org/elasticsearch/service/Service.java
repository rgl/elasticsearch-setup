package org.elasticsearch.service;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.concurrent.CountDownLatch;
import java.util.Date;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.TreeSet;

import org.elasticsearch.bootstrap.Bootstrap;
import org.elasticsearch.common.logging.ESLogger;
import org.elasticsearch.common.logging.Loggers;

public class Service {
    private static Bootstrap _bootstrap;
    private static volatile CountDownLatch _stopLatch;
    private static volatile ESLogger _logger;

    public static void start(String[] args) throws Exception {
        _bootstrap = new Bootstrap();
        _bootstrap.init(null);

        Loggers.disableConsoleLogging();
        _logger = Loggers.getLogger(Service.class);

        _logger.info("starting...");

        if (_logger.isDebugEnabled()) {
            logSystemEnvironment();
        }

        _bootstrap.start();

        _logger.info("running...");
        _stopLatch = new CountDownLatch(1);
        _stopLatch.await();

        _logger.info("ended");
    }

    public static void stop(String[] args) throws Exception {
        _logger.info("stopping...");
        _stopLatch.countDown();
    }

    private static void logSystemEnvironment() {
        ClassLoader cl = Thread.currentThread().getContextClassLoader();
        if (cl == null) {
            _logger.debug("Missing currentThread context ClassLoader");
        } else {
            _logger.debug("Using context ClassLoader : " + cl.toString());
        }

        _logger.debug("Program environment:");
        Map em = System.getenv();
        for (Iterator i = em.keySet().iterator(); i.hasNext();) {
            String n = (String)i.next();
            _logger.debug(n + " ->  " + em.get(n));
        }

        _logger.debug("System properties:");
        Properties ps = System.getProperties();
        for (Iterator i = ps.keySet().iterator(); i.hasNext();) {
            String n = (String)i.next();
            _logger.debug(n + " ->  " + ps.get(n));
        }
    }
}
