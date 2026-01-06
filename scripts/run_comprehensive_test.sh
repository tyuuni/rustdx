#!/bin/bash
# RustDX 开盘日全面测试脚本
#
# 使用方式:
#   ./scripts/run_comprehensive_test.sh          # 运行所有测试
#   ./scripts/run_comprehensive_test.sh quick    # 快速测试(仅核心功能)
#   ./scripts/run_comprehensive_test.sh report   # 生成测试报告

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查环境
check_environment() {
    print_header "检查测试环境"

    # 检查是否在项目根目录
    if [ ! -f "Cargo.toml" ]; then
        print_error "请在项目根目录运行此脚本"
        exit 1
    fi

    # 检查测试文件是否存在
    if [ ! -f "tests/comprehensive_test.rs" ]; then
        print_error "测试文件不存在: tests/comprehensive_test.rs"
        exit 1
    fi

    print_success "环境检查通过"
    echo ""
}

# 编译测试
compile_tests() {
    print_header "编译测试套件"

    if cargo test --test comprehensive_test --no-run 2>&1 | grep -q "error"; then
        print_error "编译失败"
        exit 1
    else
        print_success "编译成功"
    fi
    echo ""
}

# 运行快速测试
run_quick_tests() {
    print_header "运行快速测试 (核心功能)"

    echo ""
    RUSTDX_LIVE_TEST=1 cargo test --test comprehensive_test \
        test_01_security_quotes_single \
        test_02_security_quotes_batch \
        test_03_index_quotes \
        -- --nocapture

    echo ""
    print_success "快速测试完成"
}

# 运行所有测试
run_all_tests() {
    print_header "运行全面测试"

    echo ""
    local start_time=$(date +%s)

    RUSTDX_LIVE_TEST=1 cargo test --test comprehensive_test -- --nocapture

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    print_success "所有测试完成 (耗时: ${duration}秒)"
}

# 生成测试报告
generate_report() {
    print_header "生成测试报告"

    local report_dir="reports"
    local report_file="$report_dir/$(date +%Y-%m-%d)-comprehensive-test-report.md"

    # 创建报告目录
    mkdir -p "$report_dir"

    # 运行测试并保存输出
    echo ""
    RUSTDX_LIVE_TEST=1 cargo test --test comprehensive_test -- --nocapture > /tmp/test_output.txt 2>&1

    print_success "测试报告已保存到: $report_file"
    print_success "详细输出已保存到: /tmp/test_output.txt"
}

# 显示帮助信息
show_help() {
    cat << EOF
RustDX 开盘日全面测试脚本

使用方式:
    $0 [选项]

选项:
    (无)        运行所有测试
    quick       运行快速测试(仅核心功能)
    report      生成测试报告
    help        显示此帮助信息

示例:
    $0              # 运行所有测试
    $0 quick        # 快速测试
    $0 report       # 生成报告

环境变量:
    RUSTDX_SKIP_INTEGRATION_TESTS=1    跳过需要网络的测试
    RUSTDX_LIVE_TEST=1                 运行实时测试

EOF
}

# 主函数
main() {
    local command=${1:-}

    case "$command" in
        quick)
            check_environment
            compile_tests
            run_quick_tests
            ;;
        report)
            check_environment
            compile_tests
            generate_report
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            check_environment
            compile_tests
            run_all_tests
            ;;
        *)
            print_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
