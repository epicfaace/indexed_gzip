
bash ./.ci/create_test_env.sh "./test.env"
source ./.ci/activate_env.sh "./test.env"
bash ./.ci/build_dev_indexed_gzip_fileobj_fork_epicfaace.sh "./test.env" && TEST_SUITE="not (slow_test or zran_test)" bash  ./.ci/run_tests.sh "./test.env"


bash ./.ci/build_dev_indexed_gzip_fileobj_fork_epicfaace.sh "./test.env" && TEST_SUITE="not (slow_test) and zran_test" bash  ./.ci/run_tests.sh "./test.env"

bash ./.ci/build_dev_indexed_gzip_fileobj_fork_epicfaace.sh "./test.env" && TEST_SUITE="not (slow_test) and indexed_gzip_fileobj_fork_epicfaace_test" bash  ./.ci/run_tests.sh "./test.env"

bash ./.ci/build_dev_indexed_gzip_fileobj_fork_epicfaace.sh "./test.env" && TEST_SUITE="not (slow_test)" bash  ./.ci/run_tests.sh "./test.env"

python setup.py sdist
bash ./.ci/build_wheels.sh
indexed_gzip_fileobj_fork_epicfaace_fileobj_fork_epicfaace-1.4.0.tar.gz