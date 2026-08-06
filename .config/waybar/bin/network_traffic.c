#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_IFACES 32
#define MAX_LINE 512
#define DEFAULT_RATE_MAX 1000000

typedef struct {
    char name[32];
    unsigned long long rx_bytes;
    unsigned long long tx_bytes;
    unsigned long long rx_rate;
    unsigned long long tx_rate;
    int is_target;
    int initialized;
} Iface;

static void human_readable(unsigned long long bytes, char *out, size_t out_size) {
    const char *units[] = {"B", "K", "M", "G", "T", "P"};
    int unit_idx = 0;
    double val = (double)bytes;

    while (val >= 1024.0 && unit_idx < 5) {
        val /= 1024.0;
        unit_idx++;
    }

    if (unit_idx == 0) {
        snprintf(out, out_size, "%lluB", bytes);
    } else {
        snprintf(out, out_size, "%.1f%s", val, units[unit_idx]);
    }
}

int main(int argc, char *argv[]) {
    int interval = 1;
    unsigned long long rate_max = DEFAULT_RATE_MAX;
    int opt;

    while ((opt = getopt(argc, argv, "t:")) != -1) {
        if (opt == 't') {
            interval = atoi(optarg);
            if (interval < 1) interval = 1;
        }
    }

    Iface ifaces[MAX_IFACES] = {0};
    int iface_count = 0;
    int target_mode_all = (optind >= argc);

    // 了解用户指定的网卡
    if (!target_mode_all) {
        for (int i = optind; i < argc && iface_count < MAX_IFACES; i++) {
            strncpy(ifaces[iface_count].name, argv[i], sizeof(ifaces[0].name) - 1);
            ifaces[iface_count].is_target = 1;
            iface_count++;
        }
    }

    char line[MAX_LINE];
    char tooltip[2048];
    char rx_str[16], tx_str[16];

    while (1) {
        FILE *fp = fopen("/proc/net/dev", "r");
        if (!fp) {
            perror("Failed to open /proc/net/dev");
            return 1;
        }

        unsigned long long total_rx_rate = 0;
        unsigned long long total_tx_rate = 0;
        tooltip[0] = '\0';

        // 跳过前两行表头
        if (!fgets(line, sizeof(line), fp) || !fgets(line, sizeof(line), fp)) {
            fclose(fp);
            continue;
        }

        while (fgets(line, sizeof(line), fp)) {
            char name[32];
            unsigned long long rx = 0, tx = 0;
            char *colon = strchr(line, ':');
            if (!colon) continue;

            *colon = '\0';
            sscanf(line, "%s", name);
            
            // 跳过 lo 回环接口
            if (strcmp(name, "lo") == 0) continue;

            // 过滤目标网卡
            int target_idx = -1;
            if (target_mode_all) {
                for (int i = 0; i < iface_count; i++) {
                    if (strcmp(ifaces[i].name, name) == 0) {
                        target_idx = i;
                        break;
                    }
                }
                if (target_idx == -1 && iface_count < MAX_IFACES) {
                    target_idx = iface_count++;
                    strncpy(ifaces[target_idx].name, name, sizeof(ifaces[0].name) - 1);
                    ifaces[target_idx].is_target = 1;
                }
            } else {
                for (int i = 0; i < iface_count; i++) {
                    if (strcmp(ifaces[i].name, name) == 0) {
                        target_idx = i;
                        break;
                    }
                }
            }

            if (target_idx == -1 || !ifaces[target_idx].is_target) continue;

            // 解析 rx (第1项) 和 tx (第9项)
            sscanf(colon + 1, "%llu %*u %*u %*u %*u %*u %*u %*u %llu", &rx, &tx);

            Iface *iface = &ifaces[target_idx];
            if (iface->initialized) {
                iface->rx_rate = (rx >= iface->rx_bytes) ? (rx - iface->rx_bytes) / interval : 0;
                iface->tx_rate = (tx >= iface->tx_bytes) ? (tx - iface->tx_bytes) / interval : 0;

                total_rx_rate += iface->rx_rate;
                total_tx_rate += iface->tx_rate;

                char if_rx[16], if_tx[16];
                human_readable(iface->rx_rate, if_rx, sizeof(if_rx));
                human_readable(iface->tx_rate, if_tx, sizeof(if_tx));

                char entry[128];
                snprintf(entry, sizeof(entry), "%s:  ↓%s/s   ↑%s/s\\n", iface->name, if_rx, if_tx);
                strcat(tooltip, entry);
            }

            iface->rx_bytes = rx;
            iface->tx_bytes = tx;
            iface->initialized = 1;
        }

        fclose(fp);

        // 移除末尾换行符转义
        size_t tlen = strlen(tooltip);
        if (tlen >= 2 && tooltip[tlen - 2] == '\\' && tooltip[tlen - 1] == 'n') {
            tooltip[tlen - 2] = '\0';
        }

        human_readable(total_rx_rate, rx_str, sizeof(rx_str));
        human_readable(total_tx_rate, tx_str, sizeof(tx_str));

        int percentage = (int)((total_rx_rate + total_tx_rate) * 100 / rate_max);
        if (percentage > 100) percentage = 100;

        // 输出 JSON 并在结尾手动 fflush 刷新缓冲区（Waybar 必需）
        printf("{\"text\": \"%4s↓  %4s↑ \", \"tooltip\": \"%s\", \"percentage\": %d}\n",
               rx_str, tx_str, tooltip, percentage);
        fflush(stdout);

        sleep(interval);
    }

    return 0;
}
